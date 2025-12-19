import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Frostflake',
  description: 'Beginner-friendly Nix flake docs',
  themeConfig: {
    logo: '/nixos-logo.svg',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Architecture', link: '/architecture' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Hosts', link: '/hosts' },
      { text: 'Modules', link: '/modules' },
      { text: 'Home Environment', link: '/home' },
      { text: 'FAQ', link: '/faq' }
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Getting Started', link: '/getting-started' },
          { text: 'Architecture', link: '/architecture' },
          { text: 'Host Matrix', link: '/hosts' },
          { text: 'Developer Workflow', link: '/dev-workflow' },
          { text: 'Deploying Hosts', link: '/deploying' },
          { text: 'Customization', link: '/customization' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'Modules', link: '/modules' },
          { text: 'Home Environment', link: '/home' },
          { text: 'FAQ', link: '/faq' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/j4v3l/frostflake' }
    ]
  },
  head: [
    [
      'link',
      { rel: 'stylesheet', href: 'https://nixos.org/nixos.css' }
    ]
  ]
})
