from __future__ import print_function

import json

for n in range(10):
    record = {
      'licence_number': 'XYZ{}'.format(n),
      'source_url': 'http://example.com',
      'sample_date': '2014-06-01'
    }
    print(json.dumps(record))
