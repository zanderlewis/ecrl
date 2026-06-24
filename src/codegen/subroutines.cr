class MecanumSubroutine
  def self.generate(io : IO)
    io << "    private void driveMecanum(double forward, double strafe, double rotate) {\n"
    io << "        double fl = forward + strafe + rotate;\n"
    io << "        double fr = forward - strafe - rotate;\n"
    io << "        double bl = forward - strafe + rotate;\n"
    io << "        double br = forward + strafe - rotate;\n\n"
    io << "        double max = Math.max(Math.abs(fl), Math.abs(fr));\n"
    io << "        max = Math.max(max, Math.abs(bl));\n"
    io << "        max = Math.max(max, Math.abs(br));\n"
    io << "        if (max > 1.0) {\n"
    io << "            fl /= max; fr /= max; bl /= max; br /= max;\n"
    io << "        }\n"
    io << "        leftFront.setPower(fl);\n"
    io << "        rightFront.setPower(fr);\n"
    io << "        leftBack.setPower(bl);\n"
    io << "        rightBack.setPower(br);\n"
    io << "    }\n"
  end
end
