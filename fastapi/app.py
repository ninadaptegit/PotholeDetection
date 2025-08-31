from ultralytics import YOLO

from fastapi import FastAPI
from fastapi.responses import FileResponse,JSONResponse
from fastapi import Request
from fastapi import File,UploadFile
import time
import csv
from pathlib import Path

Base_DIR = Path(__file__).parent
index_path = Base_DIR / 'index.html'
output_path = './outputs/'
app = FastAPI()
model = YOLO('./model1.pt')
@app.get('/')
async def index(request:Request):
    return FileResponse(index_path)

def save_output(output,file_name):
    try:
        field_names = ['class_idx', 'conf', 'xmin', 'ymin', 'xmax', 'ymax']
        ans = []
        file_name = file_name.split('.')[0]
        

        
        for box in output[0].boxes.data:
            hold = {}
            hold['class_idx'] = int(box[5].item())  
            hold['conf'] = box[4].item()           
            hold['xmin'] = box[0].item()           
            hold['ymin'] = box[1].item()           
            hold['xmax'] = box[2].item()           
            hold['ymax'] = box[3].item()          
            ans.append(hold)

        
        with open(output_path+file_name+'.csv','w',newline='') as f:
                writer = csv.DictWriter(f, fieldnames=field_names)
                writer.writeheader()
                writer.writerows(ans)

        return ans
    except Exception as e:
        print(e)

@app.post('/upload')
async def getupload(file:UploadFile):
    try:
        file_name = str(time.time())+file.filename
        file_path = './uploads/'+ file_name
        with open(file_path,'wb') as f:
            contents = await file.read()
            f.write(contents)

        output = model.predict(file_path)
        output[0].save()
        out = save_output(output,file_name)
        return JSONResponse({'result':out})
    except Exception as e:
        return JSONResponse({'result' : []})
    finally:
        await file.close()