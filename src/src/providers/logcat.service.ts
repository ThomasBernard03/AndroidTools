import { Injectable } from '@angular/core';
import { Logcat } from '../models/logcat.interface';
import { Subject, Observable } from 'rxjs';
import { ElectronService } from './electron.service'; // Mettez à jour le chemin

@Injectable({
    providedIn: 'root'
})
export class LogcatService {
    private logcatSubject: Subject<Logcat[]> = new Subject<Logcat[]>();

    constructor(private electronService: ElectronService) {}

    subscribe(): Observable<Logcat[]> {
        this.fetchLogcat();
        return this.logcatSubject.asObservable();
    }

    private fetchLogcat(): void {
        if (this.electronService.isElectron) {
            const command = 'adb logcat -d -t 1000'; // -d permet de dump le log actuel

            // const MAX_BUFFER_SIZE = 100 * 1024 * 1024;  // 10MB

            this.electronService.childProcess?.exec(command, (error, stdout, stderr) => {
                if (error) {
                    console.error(`error: ${error.message}`);
                    return;
                }
                if (stderr) {
                    console.error(`stderr: ${stderr}`);
                    return;
                }

                const logcatLines = stdout.split('\n');
                const logs: Logcat[] = logcatLines.map(line => this.parseLogcat(line));

                this.logcatSubject.next(logs);
            });
        }
    }

    private parseLogcat(line: string): Logcat {
        // Cette fonction devrait être adaptée pour analyser correctement la sortie de adb logcat.
        // Pour l'instant, je fournis une version de base.
        return {
            date: new Date(),
            level: 'INFO', // Vous devriez extraire cela de la ligne
            tag: 'TAG', // Vous devriez extraire cela de la ligne
            message: line,
            package: 'PACKAGE' // Vous devriez extraire cela de la ligne
        };
    }
}
