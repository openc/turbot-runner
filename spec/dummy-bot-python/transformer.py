import json
import sys

while True:
    line = sys.stdin.readline()
    if not line:
        break

    raw_record = json.loads(line)
    transformed_record = {
        'n': raw_record['n'],
        'goodbye': raw_record['hello'].replace('hello', 'goodbye')
    }

    print json.dumps(transformed_record)
