
.PHONY: convert-md-html
convert-md-html: clean
	for f in *.md; do pandoc "$$f" -s -o "$${f%.md}.html"; done

.PHONY: clean
clean:
	-rm *html

%.html: %.md
	pandoc $< -s -o $@
