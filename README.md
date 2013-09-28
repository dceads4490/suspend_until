suspend_until
=============

Script to make PC sleep and wake up for specific time

Source:
http://askubuntu.com/questions/61708/automatically-sleep-and-wake-up-at-specific-times

Usage:
<br/>
1. To hibernate now on until specific time, use: 
    <pre> sh suspend_until.sh 07:00 </pre>
    please note the time is in 24hour time format. Please make user the suspend_until.sh is executable by this command: sudo chmod +x suspend_until.sh
<br/>
2. To schedule your PC sleep and wake up in specific time everyday, use crontab, in terminal: 
    <pre> $ sudo crontab -e </pre>
		Then add the following script in the bottom of crontab
		<pre> 00 22 * * * /home/yourname/suspend_until.sh 03:30 </pre>
		That will make my your computer sleep from 10.00 pm to 03.30 am
