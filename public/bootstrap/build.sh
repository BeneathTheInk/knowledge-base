# Before running, make sure to replace all the files in the `less` folder.

# replace glyphicons with font-awesome
perl -pi -w -e 's{glyphicons}{font-awesome/font-awesome}g' ./less/bootstrap.less

# compile the css
lessc ./less/bootstrap.less ./css/bootstrap.css
lessc --yui-compress ./less/bootstrap.less ./css/bootstrap.min.css
