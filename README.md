# kokoro-docs

Documentation site for Kokoro Tech, served at https://docs.happykokoro.com/ (also reachable at https://kokoro-docs.pages.dev/).

This site covers only projects that have been individually verified. All projects are under development and have not been validated for production use.

Built with MkDocs and the Material theme. Hosted on Cloudflare Pages; deployments are pushed manually with `wrangler pages deploy site --project-name kokoro-docs` after running `mkdocs build` locally.

