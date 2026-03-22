# OpenSplitTime Documentation

This directory contains the Jekyll-based static documentation site for OpenSplitTime, using the [just-the-docs](https://just-the-docs.com/) theme.

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

This site is deployed to GitHub Pages automatically via GitHub Actions when changes are pushed to the `master` branch.

The documentation is available at: [https://docs.opensplittime.org](https://docs.opensplittime.org)

### How It Works

1. Changes to the `docs/` directory are pushed to the `master` branch
2. GitHub Actions workflow (`.github/workflows/deploy-docs.yml`) is triggered
3. Jekyll builds the site with production settings
4. Built site is deployed to GitHub Pages
5. Site is available within a few minutes

### Manual Deployment

To manually trigger a deployment:
1. Go to the [Actions tab](https://github.com/SplitTime/OpenSplitTime/actions)
2. Select "Deploy Jekyll Documentation to GitHub Pages"
3. Click "Run workflow"

## Structure

- `_sass/color_schemes/` - Custom color scheme (OST brand colors)
- `_config.yml` - Jekyll configuration
- `index.md` - Homepage
- `getting-started/` - Getting started guides
- `management/` - Event management guides
- `ost-remote/` - OST Remote documentation
- `api/` - API documentation
- `user-info/` - User information

## Contributing

When adding new documentation:

1. Create Markdown files (`.md`) in the appropriate directory
2. Add front matter with `title`, `parent` (matching the section's index page title), and `nav_order`
3. Use standard Markdown syntax
4. Test locally before submitting PR

## Learn More

- [just-the-docs Documentation](https://just-the-docs.com/)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
