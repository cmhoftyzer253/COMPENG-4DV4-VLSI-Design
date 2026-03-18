#!/bin/tcsh

# ---- project directory ----
set PROJ = "$cwd"
cd "$PROJ" || exit 1

# ---- tool environments ----
source /CMC/scripts/cadence.xceliummain24.03.013.csh
source /CMC/scripts/synopsys.verdi.2021.09-SP1-1.csh

# ---- folders ----
mkdir -p logs waves

# ---- loop tests ----
foreach i (0 1 2 3 4 5 6 7 8)
    set T = "I${i}"
    echo ""
    echo "==================== ${T} ===================="

    # Run + log
    xmverilog testbench.v alu.v +define+${T} +access+rw |& tee logs/${T}.txt
    if ( $status != 0 ) then
        echo "${T}: RUN ERROR (see logs/${T}.txt)"
        echo -n "Press ENTER to continue... "
        set dummy = $<
        continue
    endif

    # Save VCD uniquely
    if ( -e tb.vcd ) then
        cp -f tb.vcd waves/tb_${T}.vcd
        echo "Saved: waves/tb_${T}.vcd"
    else
        echo "${T}: WARNING: tb.vcd not found"
    endif

    # Summarize pass/fail
    if ( `grep -c "ALL PASS" logs/${T}.txt` > 0 ) then
        echo "${T}: PASS"
    else if ( `egrep -c "Wrong!|Error!|Unknown output" logs/${T}.txt` > 0 ) then
        echo "${T}: FAIL (see logs/${T}.txt)"
    else
        echo "${T}: UNKNOWN (see logs/${T}.txt)"
    endif

    echo -n "Press ENTER to open nWave for ${T} (close nWave to continue)... "
    set dummy = $<
    if ( -e waves/tb_${T}.vcd ) then
        nWave waves/tb_${T}.vcd
    endif

    echo -n "Press ENTER for next test... "
    set dummy = $<
end

echo ""
echo "Done."
echo "Logs:  ${PROJ}/logs"
echo "Waves: ${PROJ}/waves"

