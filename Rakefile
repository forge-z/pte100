task :test do
  test_files = ["test/test_pte_lint.rb", "test/test_consistency.rb", "test/test_corpus_manifest.rb", "test/test_ingest_corpus.rb"]
  test_files.each do |test_file|
    abort "Testes falharam em #{test_file}" unless system(RbConfig.ruby, "-Ilib", "-Itest", test_file)
  end
end
