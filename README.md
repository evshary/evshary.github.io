# Introduction

The blog uses hexo and hexo-theme-next.

## Configuration

* Config for hexo: `_config.yml`
* Config for hexo-theme-next:
  * modified: `_config.next.yml`
  * original: `_config.next_origin.yml`

## Update blogs

* Install just (You might need to install cargo first)

   ```bash
   cargo install just
   ```

* Install necessary packages

   ```bash
   just prepare
   ```

* Build and run

  ```bash
  just
  just run
  ```
