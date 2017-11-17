
version_file=lib/fdk/version.rb
docker run --rm -it -v $PWD:/app -w /app treeder/bump --filename $version_file "$(git log -1 --pretty=%B)"
version=$(grep -m1 -Eo "[0-9]+\.[0-9]+\.[0-9]+" $version_file)
echo "Version: $version"

tag="$version"
git add -u
git commit -m "Ruby FDK: $version release [skip ci]"
# todo: might make sense to move this into it's own repo so it can have it's own versioning at some point
git tag -f -a $tag -m "Ruby FDK version $version"
git push
git push origin $tag

gem build fdk.gemspec
gem push fdk-$version.gem
