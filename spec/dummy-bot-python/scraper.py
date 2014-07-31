from __future__ import print_function

import json
import sys

print('hello from python', file=sys.stderr)

print(json.dumps({'n': 5, 'hello': 'hello, 5'}))
print(json.dumps({'n': 6, 'hello': 'hello, 6'}))
print(json.dumps({'n': 7}))
print(json.dumps({'n': 8, 'hello': 'hello, 8'}))
