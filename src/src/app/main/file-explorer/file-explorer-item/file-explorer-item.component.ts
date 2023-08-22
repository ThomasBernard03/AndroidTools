import { Component, Input } from '@angular/core';
import { File } from 'src/models/file.interface';

@Component({
  selector: 'app-file-explorer-item',
  templateUrl: './file-explorer-item.component.html',
  styleUrls: ['./file-explorer-item.component.scss']
})
export class FileExplorerItemComponent {

  @Input() file! : File
}
