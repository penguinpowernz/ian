# Ian

A Debian CLI package hacking tool named in memory of the late Ian Murdock.

This tool will help you to create and maintain git repositories that contain simple
Debian packages and tries to mimic the CLI of other popular tools such as git and
bundler.

It is intended to be helpful when integrating other build tools/systems and
with CI/CD.

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

Create a new package (like `bundle new gemname`):

    $ ian new mycoolpackage

Init an existing directory (like `git init`):

    $ ian init

Show the info for the package (basically `cat DEBAIN/control`):

    $ ian info

Set info in the control file:

    $ ian set -v 2.3.1-beta
    $ ian set -a amd64

Build a package:

    $ ian pkg

Before building a package ian will determine the installed size, leave out any
cruft (such as the `.git` directory) and move READMEs and the like to `/usr/share/doc`.

## TODO

- [ ] MD5sums generation
- [x] finish package generation code
- [ ] ADD SPECS!!!!
- [ ] Nicer output
- [ ] add git tags when version changes
- [ ] allow packaging past versions from git tags

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/penguinpowernz/ian.

## In Memory Of

In memory of Ian Ashley Murdock (1973 - 2015) founder of the Debian project.
