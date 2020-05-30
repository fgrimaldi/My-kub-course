#mac
docker run --rm -p 80:80 -v $(PWD):/desotech hermedia/mkdocs:latest

#linux
docker run --rm -p 80:80 -v $(pwd):/desotech hermedia/mkdocs:latest
