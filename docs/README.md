# OpenSplitTime Documentation

This directory contains the Jekyll-based static documentation site for OpenSplitTime.

## Local Development

### Prerequisites

- Ruby 3.0 or higher
- Bundler

### Setup

```bash
cd docs
bundle install
```

### Running Locally

```bash
bundle exec jekyll serve
```

The site will be available at `http://localhost:4000`.

### Building for Production

```bash
bundle exec jekyll build
```

The static site will be generated in the `_site/` directory.

## Deployment

This site is deployed to GitHub Pages automatically from the `main` branch.

## Structure

- `_layouts/` - Page templates
- `_config.yml` - Jekyll configuration
- `index.md` - Homepage
- (Additional content will be added during migration)

## Contributing

When adding new documentation:

1. Create Markdown files (`.md`) in the appropriate directory
2. Add front matter with `layout` and `title`
3. Use standard Markdown syntax
4. Test locally before submitting PR

## Learn More

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
