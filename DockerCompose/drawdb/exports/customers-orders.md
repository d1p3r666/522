erDiagram
	orders }o--|| customers : references

	orders {
		INTEGER id
		INTEGER customer_id
	}

	customers {
		INTEGER id
	}