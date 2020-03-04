#! /bin/sh
set -e
if [ $# -eq 0 ]; then
	AWK=/usr/bin/awk
elif [ $# -eq 1 ]; then
	AWK="$1"
fi
$AWK -f csv.awk -f - /dev/fd/3 <<'EOF' 3<<'EOF' 4<<'EOF' \
	| $AWK -f csv.awk -f /dev/fd/3 3<<'EOF' \
	| $AWK -v awk="$AWK" -f csv.awk -f /dev/fd/3 3<<'EOF'
function fail(number)
{
	printf "Test %d failed\n", number > "/dev/stderr"
	exit 1
}
function count(record	, number, index_)
{
	for (index_ in record) ++number
	return number
}
BEGIN {
	if (csv_parse_line(record, "foo") != 1) fail(1)
	if (!(1 in record)) fail(2)
	if (record[1] != "foo") fail(3)
	if (count(record) != 1) fail(4)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "foo,bar") != 2) fail(5)
	if (!(1 in record)) fail(6)
	if (!(2 in record)) fail(7)
	if (record[1] != "foo") fail(8)
	if (record[2] != "bar") fail(9)
	if (count(record) != 2) fail(10)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "\"foo\"") != 1) fail(11)
	if (!(1 in record)) fail(12)
	if (record[1] != "foo") fail(13)
	if (count(record) != 1) fail(14)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "\"foo,bar\"") != 1) fail(15)
	if (!(1 in record)) fail(16)
	if (record[1] != "foo,bar") fail(17)
	if (count(record) != 1) fail(18)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "\"foo") != 0) fail(19)
	if (csv_parse_line(record, "bar\"") != 1) fail(20)
	if (!(1 in record)) fail(21)
	if (record[1] != "foo\nbar") fail(22)
	if (count(record) != 1) fail(23)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "") != 1) fail(24)
	if (!(1 in record)) fail(25)
	if (record[1] != "") fail(26)
	if (count(record) != 1) fail(27)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "foo\r") != 1) fail(28)
	if (!(1 in record)) fail(29)
	if (record[1] != "foo") fail(30)
	if (count(record) != 1) fail(31)
	for (index_ in record) delete record[index_]

	if (csv_parse_line(record, "\"foo\r") != 0) fail(32)
	if (csv_parse_line(record, "bar\"\r") != 1) fail(33)
	if (!(1 in record)) fail(34)
	if (record[1] != "foo\nbar") fail(35)
	if (count(record) != 1) fail(36)
	for (index_ in record) delete record[index_]

	record[1] = "foo"
	csv_header(record)
	if (1 in record) fail(37)
	if (!("foo" in record)) fail(38)
	if (record["foo"] != 1) fail(39)
	if (count(record) != 1) fail(40)
	for (index_ in record) delete record[index_]

	if (csv_read(record) != 2) fail(41)
	if (!(1 in record)) fail(42)
	if (record[1] != "foo") fail(43)
	if (!(2 in record)) fail(44)
	if (record[2] != "bar") fail(45)
	if (count(record) != 2) fail(46)
	if (csv_read(record) != 0) fail(47)
	for (index_ in record) delete record[index_]

	if (csv_read_file(record, "/dev/fd/4") != 2) fail(48)
	if (!(1 in record)) fail(49)
	if (record[1] != "foo") fail(50)
	if (!(2 in record)) fail(51)
	if (record[2] != "bar") fail(52)
	if (count(record) != 2) fail(53)
	if (csv_read_file(record, "/dev/fd/4") != 0) fail(54)
	close("/dev/fd/4")
	for (index_ in record) delete record[index_]

	if (csv_read_command(record, "echo foo,bar") != 2) fail(55)
	if (!(1 in record)) fail(56)
	if (record[1] != "foo") fail(57)
	if (!(2 in record)) fail(58)
	if (record[2] != "bar") fail(59)
	if (count(record) != 2) fail(60)
	if (csv_read_command(record, "echo foo,bar") != 0) fail(61)
	close("echo foo,bar")
	for (index_ in record) delete record[index_]

	record[1] = "foo"
	record[2] = "bar"
	csv_write(record)
	record[1] = "foo,bar"
	delete record[2]
	csv_write(record)
	record[1] = "baz\nquux"
	csv_write(record)
}
EOF
foo,bar
EOF
foo,bar
EOF
function fail(number)
{
	printf "Test %d failed\n", number > "/dev/stderr"
	exit 1
}
BEGIN {
	if ((getline line) != 1) fail(62)
	if (line != "foo,bar") fail(63)
	if ((getline line) != 1) fail(64)
	if (line != "\"foo,bar\"") fail(65)
	if ((getline line) != 1) fail(66)
	if (line != "\"baz") fail(67)
	if ((getline line) != 1) fail(68)
	if (line != "quux\"") fail(69)
	if ((getline line) != 0) fail(70)

	record[1] = "bar"
	record[2] = "baz"
	csv_write_file(record, "/dev/stdout")
	close("/dev/stdout")
}
EOF
function fail(number)
{
	printf "Test %d failed\n", number > "/dev/stderr"
	exit 1
}
BEGIN {
	if ((getline line) != 1) fail(71)
	if (line != "bar,baz") fail(72)
	if ((getline line) != 0) fail(73)
	
	# here we rely on the return value of close() equalling the exit code
	# POSIX only specifies that close() should return non-zero on failure
	# works fine in mawk and gawk
	# but original awk and busybox awk multiply the code by 256
	# (presumably they're returning the status from waitpid() unchanged)
	# not a big deal really
	command = \
		awk " '\n" \
		"BEGIN {\n" \
		"	if ((getline line) != 1) exit 74\n" \
		"	if (line != \"foo,bar\") exit 75\n" \
		"	if ((getline line) != 0) exit 76\n" \
		"}\n'"
	record[1] = "foo"
	record[2] = "bar"
	csv_write_command(record, command)
	if (status = close(command)) fail(status)
}
EOF
