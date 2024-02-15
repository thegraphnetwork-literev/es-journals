## Database BiorXiv Overview

This database backup contains a collection of papers from the medRxiv server, covering the period from January 1, 2013, to February 14, 2024.

```python
import json

# Load the database
with open('data/rxivx/biorxiv/backup/biorxiv_bkp_database_2013-01-01_2024-02-14.json', 'r') as f:
    data = json.load(f)

# Get the total number of entries
print("Total number of entries:", len(data))
Total number of entries: 308495
```
