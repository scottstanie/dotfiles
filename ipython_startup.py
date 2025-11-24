from datetime import datetime
from pathlib import Path
import json
import os
import sys

import numpy as np

get_ipython().run_line_magic('load_ext', 'autoreload')
get_ipython().run_line_magic('autoreload', '2')

import IPython
s = IPython.get_ipython()

# Try to see if we're running in a terminal. If so, use the `osx` backend
if "term_title" in s.class_traits():
    get_ipython().run_line_magic('matplotlib', 'osx')
else:
    # Assume we are in a jupyter notebook. I don't know the best way to get this.
    get_ipython().run_line_magic('matplotlib', 'widget')
import matplotlib
import matplotlib.pyplot as plt
