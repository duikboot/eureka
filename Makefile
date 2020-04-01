
convert-md-html:
	for f in *.md; do pandoc "$$f" -s -o "$${f%.md}.html"; done

clean:
	rm *html
