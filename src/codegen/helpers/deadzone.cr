module DeadzoneHelper
  def self.generate(io : IO)
    io << "    private double deadzone(double value, double threshold) {\n"
    io << "        return Math.abs(value) < threshold ? 0.0 : value;\n"
    io << "    }\n"
  end
end
