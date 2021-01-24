class ZipUtil
  cattr_accessor :logger

  def self.read(tar_gz_file, output_dir)
    Zlib::GzipReader.open(tar_gz_file) do |file|
      Archive::Tar::Minitar.unpack(file, output_dir)
    end

    yield

    logger.info(
      action: 'unpack',
      file: File.basename(tar_gz_file),
      size: File.stat(tar_gz_file).size,
    )
  end

  def self.write(tar_gz_file, base_dir, src_files)
    Zlib::GzipWriter.open(tar_gz_file, Zlib::BEST_COMPRESSION) do |gzip|
      out = Minitar::Output.new(gzip)

      Dir.chdir(base_dir)
      Dir[src_files].sort.each do |file|
        Minitar.pack_file(file, out)
        logger.info(
          action: 'pack',
          csv_file: File.basename(file),
          lines: File.read(file).lines.size,
          size: File.stat(file).size,
        )
      end

      out.close
    end
  end
end
