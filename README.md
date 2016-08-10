# Ian

A Debian CLI package hacking tool named in memory of the late Ian Murdock.

This tool will help you to create and maintain git repositories that contain simple
Debian packages and tries to mimic the CLI of other popular tools such as git and
bundler.

It is intended to be helpful when integrating other build tools/systems and
with CI/CD.

## Requirements

* dpkg
* fakeroot
* rsync

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ian'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ian

## Usage

This tool is used for working with what Debian called "Binary packages" - that is
ones that have the `DEBIAN` folder in capitals to slap Debian packages together
quickly.  It uses `dpkg-deb -b` in the background which most Debian package
maintainers frown at but it is suitable enough for rolling your own packages
quickly, and it scratches an itch.

Help is available using `-h` or `--help` with all commands.

**Create a new package** (like `bundle new gemname`):

    $ ian new mycoolpackage

This will create a folder called `mycoolpackage` as well as the `DEBIAN` folder
inside it, a `control` file with defaults and a `postinst` file.  It will also
create an .ianignore file for stuff you don't want in the package.

**Init an existing directory** (like `git init`):

    $ ian init

This does the same as the `new` command but assumes you are already in the folder
called `mycoolpackage`.

**Show info for the package** (basically `cat DEBAIN/control`):

    $ ian info

This will print the control file as parsed by ian.  It will also warn you if you
are missing a mandatory field.

**Dependencies**:

This prints the dependencies from the control file each on a separate line:

    $ ian deps

**Set info in the control file**:

    $ ian set -v 2.3.1-beta
    $ ian set -a amd64

Using this you can programatically set the version or architecture in the control
file.

**Build a package**:

    $ ian pkg

Before building a package ian will determine the installed size and save it to
the control file.  Then the contents are rsynced to a temp dir, excluding the `.git`
folder, the `.gitignore` and `.ianignore` files, as well as anything specified in
the `.ianignore` file.

Any files left in the root of the package will be moved to `/usr/share/doc` under
a folder of the same name as the generated package.

Finally the package is built into a `pkg` folder in the format `name_version_arch`.

**Releasing a package**:

Tagging commits with the package version can be done using this command:

    $ ian release

This takes the version from the control file, tags the current commit with that
version (prepending it with a `v`) and then builds the package as above.

    $ ian release 4.2.8-beta

This does the same as before, however first it will take the version number in
the argument, write it to the control file and commit the control file.

**Show versions**:

Show the versions by using this command:

    $ ian versions

## Help

Need help with the control files?  Try these links:

* https://www.debian.org/doc/debian-policy/ch-controlfields.html
* https://www.debian.org/doc/debian-policy/ch-relationships.html

## TODO

- [ ] MD5sums generation
- [x] finish package generation code
- [x] ADD SPECS!!!!
- [ ] ADD MORE SPECS!!!!
- [ ] Nicer output
- [ ] add commands to help with releasing new versions/tagging
- [ ] allow packaging past versions from git tags
- [ ] add option for semver enforcement
- [ ] remove rsync dependency

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/penguinpowernz/ian.

## In Memory Of

In memory of Ian Ashley Murdock (1973 - 2015) founder of the Debian project.
