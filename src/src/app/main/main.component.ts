import { Component } from '@angular/core';
import packageJson from '../../../package.json';

@Component({
  selector: 'app-main',
  templateUrl: './main.component.html',
  styleUrls: ['./main.component.scss']
})
export class MainComponent {

  public version: string = packageJson.version;
  
}
