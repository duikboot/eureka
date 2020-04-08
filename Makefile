
.PHONY: convert-md-html
convert-md-html: clean
	for f in *.md; do pandoc "$$f" -s -o "$${f%.md}.html"; done

clean:
	-rm *html

%.html: %.md
	pandoc $< -s -o $@
