wvConvertFile -win $_nWave1 -o \
           "/home/v72180/mydata/Mini_Project_01/MiniProject_01/MiniProject_01/1101_hw1/waves/tb_I4.vcd.fsdb" \
           "waves/tb_I4.vcd"
wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/v72180/mydata/Mini_Project_01/MiniProject_01/MiniProject_01/1101_hw1/waves/tb_I4.vcd.fsdb}
wvSetPosition -win $_nWave1 {("G1" 0)}
nMemSetPreference
verdiSetActWin -win $_nWave1
wvExit
