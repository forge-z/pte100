task :test do
  test_files = ["test/test_pte_lint.rb", "test/test_cli.rb", "test/test_consistency.rb", "test/test_corpus_manifest.rb", "test/test_ingest_corpus.rb"]
  test_files.each do |test_file|
    abort "Testes falharam em #{test_file}" unless system(RbConfig.ruby, "-Ilib", "-Itest", test_file)
  end
end

task :reviewer do
  Dir.chdir("reviewer-webapp") do
    abort "Testes do revisor falharam" unless system("bundle", "exec", RbConfig.ruby, "-Iserver", "test/reviewer_webapp_test.rb")
    abort "Testes HTTP do revisor falharam" unless system("bundle", "exec", RbConfig.ruby, "-Iserver", "test/reviewer_server_test.rb")
  end
end

task :validate do
  abort "Validação do repositório falhou" unless system(RbConfig.ruby, "tools/validate_repo.rb")
end

task verify: [:test, :reviewer, :validate]
