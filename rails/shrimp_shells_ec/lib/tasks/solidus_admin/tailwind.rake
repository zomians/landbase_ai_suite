# frozen_string_literal: true

namespace :solidus_admin do
  namespace :tailwindcss do
    root = Rails.root
    tailwindcss = Tailwindcss::Ruby.executable

    tailwindcss_command = [
      tailwindcss,
      "--config", root.join("config/solidus_admin/tailwind.config.js"),
      "--input", root.join("app/assets/stylesheets/solidus_admin/application.tailwind.css"),
      "--output", root.join("app/assets/builds/solidus_admin/tailwind.css"),
    ]

    desc 'Build Tailwind CSS'
    task :build do
      sh tailwindcss_command.shelljoin
    end

    desc 'Watch Tailwind CSS'
    task :watch do
      sh (tailwindcss_command + ['--watch']).shelljoin
    end
  end
end

# Attach Tailwind CSS build to other tasks.
%w[
  assets:precompile
  test:prepare
  spec:prepare
  db:test:prepare
].each do |task_name|
  next unless Rake::Task.task_defined?(task_name)

  Rake::Task[task_name].enhance(['solidus_admin:tailwindcss:build'])
end
