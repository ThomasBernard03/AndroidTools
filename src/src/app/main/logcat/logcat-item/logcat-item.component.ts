import { Component, Input } from '@angular/core';
import { Logcat } from 'src/models/logcat.interface';

@Component({
  selector: 'app-logcat-item',
  templateUrl: './logcat-item.component.html',
  styleUrls: ['./logcat-item.component.scss']
})
export class LogcatItemComponent {

  @Input() logcat!: Logcat;

}
