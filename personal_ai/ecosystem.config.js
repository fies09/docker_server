module.exports = {
  apps: [
    {
      name: 'personal-ai-backend',
      script: './start-backend.sh',
      cwd: '/Users/fanyong/Desktop/code/python/docker_server/personal_ai',
      interpreter: 'bash',
      instances: 1,
      autorestart: true,
      watch: false,
      restart_delay: 2000,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PATH: process.env.PATH || '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
        PYTHONPATH: '/Users/fanyong/Desktop/code/python/personal_ai',
        ENVIRONMENT: 'production'
      },
      env_development: {
        NODE_ENV: 'development',
        PATH: process.env.PATH || '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
        PYTHONPATH: '/Users/fanyong/Desktop/code/python/personal_ai',
        ENVIRONMENT: 'development',
        DEBUG: 'True',
        LOG_LEVEL: 'DEBUG'
      },
      error_file: './logs/personal-ai-backend-error.log',
      out_file: './logs/personal-ai-backend-out.log',
      time: true
    },
    {
      name: 'personal-ai-frontend',
      script: './start-frontend.sh',
      cwd: '/Users/fanyong/Desktop/code/python/docker_server/personal_ai',
      interpreter: 'bash',
      instances: 1,
      autorestart: true,
      watch: false,
      restart_delay: 2000,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PATH: process.env.PATH || '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
        PORT: '3000',
        HOSTNAME: '0.0.0.0',
        NEXT_PUBLIC_API_URL: 'http://localhost:8008'
      },
      env_development: {
        NODE_ENV: 'development',
        PATH: process.env.PATH || '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
        PORT: '3001',
        HOSTNAME: '0.0.0.0',
        NEXT_PUBLIC_API_URL: 'http://localhost:8008'
      },
      error_file: './logs/personal-ai-frontend-error.log',
      out_file: './logs/personal-ai-frontend-out.log',
      time: true
    }
  ]
}
