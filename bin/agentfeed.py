"""What a running coding agent is doing, as short lines read from its log. Used by agent-work and
agent-review, which sit next to this file."""

import json
import re


def duration(seconds):
    seconds = int(seconds)
    return f"{seconds // 60}m{seconds % 60:02d}s" if seconds >= 60 else f"{seconds}s"


def shorten(text, width):
    return text if len(text) <= width else text[:width - 1] + "…"


class Feed:
    """Short lines about what a running tool is doing, read from the new part of its log."""

    def __init__(self, kind, path, prefixes, *, say=None):
        """kind is codex, claude, or anything else for the last line of a plain log. Paths under
        the prefixes are shown relative to them. An agent's own words start with say (default:
        the kind and a colon)."""
        self.kind, self.path = kind, path
        self.say = f"{kind}: " if say is None else say
        self.prefixes = [f"{prefix}/" for prefix in prefixes]
        self.offset = 0
        self.expect = None
        self.edits = []
        self.script = []

    def lines(self):
        with self.path.open("rb") as stream:
            stream.seek(self.offset)
            data = stream.read()
        end = data.rfind(b"\n") + 1
        self.offset += end
        new = data[:end].decode("utf-8", errors="replace").splitlines()
        if self.kind == "codex":
            return list(self.codex(new))
        if self.kind == "claude":
            return list(self.claude(new))
        return [self.relative(line.strip()) for line in new if line.strip()][-1:]

    def relative(self, text):
        for prefix in self.prefixes:
            text = text.replace(prefix, "")
        return text

    def codex(self, lines):
        """codex exec prints blocks headed by a line `exec`, `codex` or `apply patch`."""
        for line in lines:
            if self.expect == "patch":
                if line.startswith("/"):
                    self.edits.append(self.relative(line))
                    continue
                if line.startswith("patch:"):
                    if line != "patch: completed":
                        yield line
                    continue
                self.expect = None
                if self.edits:
                    yield "edited " + ", ".join(self.edits)
                    self.edits = []
            if self.expect == "exec":
                # The command, possibly over several lines, ends with ` in <workdir>`.
                match = re.fullmatch(r"(.*) in (/\S*)", line)
                if match or not re.match(r" (succeeded|exited) ", line):
                    self.script.append(match[1] if match else line)
                    if not match:
                        continue
                self.expect = None
                yield "$ " + self.command(self.script)
                self.script = []
                if match:
                    continue
            if self.expect == "codex":
                if line.strip():
                    self.expect = None
                    yield self.say + line.strip()
            elif line in ("exec", "codex", "apply patch"):
                self.expect = "patch" if line == "apply patch" else line
            elif match := re.fullmatch(r" exited (-?\d+) in \S+:", line):
                yield f"  exit {match[1]}"

    def command(self, lines):
        command = re.sub(r"^\S*/(?:ba|z)?sh -l?c ", "", " ⏎ ".join(line.strip() for line in lines))
        quote = command[:1]
        if quote in ("'", '"'):
            command = command[1:].removesuffix(quote)
        return self.relative(command)

    def claude(self, lines):
        """claude -p --output-format stream-json prints one JSON event per line."""
        for line in lines:
            event = json.loads(line)
            if event["type"] != "assistant":
                continue
            for item in event["message"]["content"]:
                if item["type"] == "text" and item["text"].strip():
                    yield self.say + item["text"].strip().splitlines()[0]
                elif item["type"] == "tool_use" and item["name"] == "Bash":
                    yield "$ " + self.relative(item["input"]["command"].splitlines()[0])
                elif item["type"] == "tool_use":
                    data = item["input"]
                    value = next((data[key] for key in ("file_path", "pattern", "path", "url", "query")
                                  if isinstance(data.get(key), str)), "")
                    yield f"{item['name']} {self.relative(value)}".rstrip()
