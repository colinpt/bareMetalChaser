# bareMetalChaser
An LED based arcade-style game for an OS-less pi 3+ coded in ARM assembly

<h2>How to play</h2>
The rules are simple. Your objective is to hit the button when the green LED is lit.
<br>You start with 5 lives displayed in binary on the blue LEDs.
<br>If you hit a yellow light, you lose 1 life.
<br>If you hit a red light, you lose 2 lives.
<br>Any time you hit the green light, your score is increased by one, and the speed of the light increases.
<br>Once you run out of lives, your score will be displayed in binary on the 5 main LEDs.
<br>To play again, hit the button once more.
<img src="assets/example.gif">

<h2>How to configure your pi</h2>
First, you will need to configure a breadboard like so.
<img src="assets/circuit.jpg" height = "300px">
<br>Secondly, you will need an empty micro sd card thats been formatted to the FAT32 file system, and has the contents of the boot folder on it.
<br>Once this has been done, simply plug in the sd card, boot up the pi, and play!
