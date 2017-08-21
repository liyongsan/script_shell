#coding=utf-8  
#pip2 install apscheduler

from apscheduler.schedulers.blocking import BlockingScheduler 
import datetime  
import time  
import os  
import zipfile    
import shutil
  
import logging  
logging.basicConfig(level=logging.DEBUG,  
                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
                datefmt='%a, %d %b %Y %H:%M:%S',  
                filename='myapp.log',  
                filemode='w')  
  
console = logging.StreamHandler()  
console.setLevel(logging.INFO)  
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')  
console.setFormatter(formatter)  
logging.getLogger('').addHandler(console)

root_path = "/data/tomcat_8080/logs/"  
  
def zip_files(zip_src):   
    logging.info( "begin zip ...")  
    print(root_path+zip_src)
    if(os.path.exists(root_path+zip_src) == False):  
        logging.info( zip_src+" not found")  
        return 
    f = zipfile.ZipFile(root_path+zip_src+".zip", 'w' ,zipfile.ZIP_DEFLATED)     
    f.write(root_path+zip_src)    
    f.close()    
    logging.info( "zip "+zip_src+" done")  
    os.remove(root_path+zip_src)
    shutil.move(root_path+zip_src+".zip",root_path+"bak/"+zip_src+".zip")
      
def tick():  
    logging.info('Tick! The time is: %s' % datetime.datetime.now())    
    now = datetime.datetime.now()  
    delta = datetime.timedelta(days=-1) #获取前一天的日期  
    n_days = now + delta  
    yesterday = n_days.strftime('%Y-%m-%d')  
    #log_name = "ccs-batch-1.2.0.RC-SNAPSHOT-3.log."+yesterday  
    log_name = "ccs-batch-1.2.0.RC-SNAPSHOT-3.log" + "." + yesterday
    #print(log_name)
    #os.chdir(root_path)
    #cmd = os.popen("ls "+ log_name)
    #for line in cmd:
    #    #print(root_path+line)
    zip_files(log_name)
  
if __name__ == '__main__':  
    scheduler = BlockingScheduler()  
    scheduler.add_job(tick,'cron', hour='15',minute='32')    #每天两点执行  
    try:
        scheduler.start()  
    except (KeyboardInterrupt, SystemExit):  
        scheduler.shutdown()
