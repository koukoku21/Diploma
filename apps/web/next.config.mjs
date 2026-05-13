/** @type {import('next').NextConfig} */
const config = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'media.miraku.kz' },
    ],
  },
};

export default config;
