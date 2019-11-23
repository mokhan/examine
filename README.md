# Examine

This gem is used to perform different types of analysis on your
code/images.

## Installation

Install it yourself as:

    $ gem install examine

## Usage

To scan a docker image: (this requires docker to be running on your system)

```bash
$ examine clair scan mokhan/minbox:latest
$ examine clair scan node:latest
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitLab at https://github.com/mokhan/examine.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
