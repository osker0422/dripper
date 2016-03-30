

orgFile = File.open("testfile/crlf.html","rb")

tmpFile = File.open("testfile/tmpfile.html","wb")


tmpFile.puts orgFile.read.gsub(/\r\n?/,"\n")

tmpFile.close
orgFile.close
