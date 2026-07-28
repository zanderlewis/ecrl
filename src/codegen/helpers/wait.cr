module WaitHelper
  def self.generate(io : IO)
    io << "    private void waitSeconds(double seconds) {\n"
    io << "        long end = System.nanoTime() + (long)(seconds * 1_000_000_000L);\n"
    io << "        while (opModeIsActive() && System.nanoTime() < end) {\n"
    io << "            idle();\n"
    io << "        }\n"
    io << "    }\n"
  end
end
