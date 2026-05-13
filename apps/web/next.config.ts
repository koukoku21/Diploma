import type { NextConfig } from 'next';

const config: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'media.miraku.kz' },
    ],
  },
};

export default config;
