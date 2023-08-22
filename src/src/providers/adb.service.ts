import { Injectable } from '@angular/core';
import { ElectronService } from './electron.service';
import { File } from '../models/file.interface';
import { Observable, Subject } from 'rxjs';


@Injectable({
    providedIn: 'root'
  })
export class AdbService {

    constructor(private electronService: ElectronService) { }

    getFiles(path: string = "/") : Observable<File[]> {

        const subject = new Subject<File[]>()

        if (this.electronService.isElectron) {
            const command = `adb shell ls ${path} -l`;

            this.electronService.childProcess?.exec(command, (error, stdout, stderr) => {
                if (error) {
                    console.error(`error: ${error.message}`);
                    return;
                }
                if (stderr) {
                    console.error(`stderr: ${stderr}`);
                    return;
                }
                console.log("adb shell ls ${path} -l : " + stdout)
                


                let files : File[] = [];

                // Skip first line

                const lines = stdout.split('\n').slice(1);

                lines.forEach(line => {

                    let fileName = line.split(" ")[line.split(" ").length - 1]

                    if (fileName != ""){ // remove empty lines
                        files.push({
                            name : fileName,
                            path : path + fileName + "/",
                            isDirectory : line.split(" ")[0].charAt(0) == "d"
                        })
                    }
                });

                subject.next(files)
                subject.complete()
            })
        }

        return subject.asObservable()
    }
}