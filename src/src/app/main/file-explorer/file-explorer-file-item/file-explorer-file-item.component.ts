import { Component, Input } from '@angular/core';
import { File } from 'src/models/file.interface';

@Component({
  selector: 'app-file-explorer-file-item',
  templateUrl: './file-explorer-file-item.component.html',
  styleUrls: ['./file-explorer-file-item.component.scss']
})
export class FileExplorerFileItemComponent {

  @Input() file! : File

}
