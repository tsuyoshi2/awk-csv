# CSV (Comma Separated Value) Input and Output
# by Christopher Cramer <tsuyoshi@yumegakanau.org>
# This program is hereby released into the public domain.

function csv_read(record	, line, status, fields)
{
	while ((status = getline line) == 1 &&
		!(fields = csv_parse_line(record, line))) ;
	if (!fields) {
		for (fields in record) delete record[fields]
		return status
	} else return fields
}
function csv_read_command(record, command	, line, status, fields)
{
	while ((status = (command | getline line)) == 1 &&
		!(fields = csv_parse_line(record, line))) ;
	if (!fields) {
		for (fields in record) delete record[fields]
		return status
	} else return fields
}
function csv_read_file(record, filename	, line, status, fields)
{
	while ((status = (getline line < filename)) == 1 &&
		!(fields = csv_parse_line(record, line))) ;
	if (!fields) {
		for (fields in record) delete record[fields]
		return status
	} else return fields
}

# parse a line of input
# record is an (initially empty) array
# return 0 if input record is continued onto next line
#	(call again with same record and next line of input)
# otherwise, return number of fields in record
# there is at least one field (an empty line yields one empty field)
# fields are stored in record[1], record[2], ... record[n]
function csv_parse_line(record, line	, position, field, quoted)
{
	if ("field" in record) {
		field = record["field"]
	} else {
		for (field in record) delete record[field]
		field = 1
	}
	quoted = record["quoted"]
	while (1) if (!quoted) {
		if (!(position = match(line, /[,"]/))) {
			if (line ~ /\r$/) {
				record[field] = \
					record[field] \
					substr(line, 1, length(line) - 1)
			} else {
				record[field] = record[field] line
			}
			delete record["field"]
			delete record["quoted"]
			return field
		} else {
			record[field] = \
				record[field] \
				substr(line, 1, position - 1)
			if (substr(line, position, 1) == ",") {
				line = substr(line, position + 1)
				++field
			} else {
				line = substr(line, position + 1)
				quoted = 1
			}
		}
	} else {
		position = match(line, /"/)
		if (!position) {
			if (line ~ /\r$/) {
				record[field] = \
					record[field] \
					substr(line, 1, length(line) - 1) \
					"\n"
			} else {
				record[field] = record[field] line "\n"
			}
			record["field"] = field
			record["quoted"] = quoted
			return 0
		} else {
			if (length(line) == position) {
				record[field] = \
					record[field] \
					substr(line, 1, position - 1)
				delete record["field"]
				delete record["quoted"]
				return field
			} else if (substr(line, position + 1, 1) == "\"") {
				record[field] = \
					record[field] \
					substr(line, 1, position)
				line = substr(line, position + 2)
			} else {
				record[field] = \
					record[field] \
					substr(line, 1, position - 1)
				line = substr(line, position + 1)
				quoted = 0
			}
		}
	}
}

function csv_header(record	, copy, index_)
{
	for (index_ in record) copy[index_] = record[index_]
	for (index_ in record) delete record[index_]
	for (index_ in copy) record[copy[index_]] = index_
}

function csv_write(record	, index_)
{
	if (1 in record) {
		printf "%s", csv_quote_field(record[1])
	}
	for (_index = 2; _index in record; ++_index) {
		printf ",%s", csv_quote_field(record[_index])
	}
	printf "\n"
}
function csv_write_command(record, command	, index_)
{
	if (1 in record) {
		printf "%s", csv_quote_field(record[1]) | command
	}
	for (_index = 2; _index in record; ++_index) {
		printf ",%s", csv_quote_field(record[_index]) | command
	}
	printf "\n" | command
}
function csv_write_file(record, filename	, index_)
{
	if (1 in record) {
		printf "%s", csv_quote_field(record[1]) > filename
	}
	for (_index = 2; _index in record; ++_index) {
		printf ",%s", csv_quote_field(record[_index]) > filename
	}
	printf "\n" > filename
}
function csv_append_file(record, filename	, index_)
{
	if (1 in record) {
		printf "%s", csv_quote_field(record[1]) >> filename
	}
	for (_index = 2; _index in record; ++_index) {
		printf ",%s", csv_quote_field(record[_index]) >> filename
	}
	printf "\n" >> filename
}

function csv_quote_field(field)
{
	if (field ~ /[",\r\n]/) {
		gsub(/"/, "\"\"", field)
		return "\"" field "\""
	} else return field
}
