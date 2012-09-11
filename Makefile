
all: buildgems

doc: rdoc

rdoc:
	rdoc -veUTF-8 -mREADME.txt README.txt LICENSE.txt lib/gogyou.rb

clean:
	@- rm -f $(GEMS)
	- cd ext && make clean

buildgems:
	gem build gogyou.gemspec

test:
	ruby -I. -I./lib test.rb
