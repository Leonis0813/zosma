class ImportUtil
  def self.target_files(csv_dir, date_string)
    csv_file = File.join(csv_dir, "#{date_string}.csv")
    if File.exist?(csv_file)
      [csv_file]
    else
      Dir[File.join(csv_dir, "*_#{date_string}.csv")]
    end
  end
end
