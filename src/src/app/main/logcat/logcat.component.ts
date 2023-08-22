import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { LogcatService } from 'src/providers/logcat.service';
import { Logcat } from 'src/models/logcat.interface';


@Component({
  selector: 'app-logcat',
  templateUrl: './logcat.component.html',
  styleUrls: ['./logcat.component.scss']
})
export class LogcatComponent implements OnInit {

  logs: Logcat[] = []

  constructor(private logcatService : LogcatService, private changeDetector : ChangeDetectorRef) { }

  ngOnInit(): void {

    this.logcatService.subscribe().subscribe(logs => {
      console.log(logs);
      this.logs = logs;
      this.changeDetector.detectChanges();
    });
  }
}
