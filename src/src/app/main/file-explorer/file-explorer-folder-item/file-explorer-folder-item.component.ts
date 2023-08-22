import { Component, Input, ChangeDetectorRef } from '@angular/core';
import { File } from 'src/models/file.interface';
import { AdbService } from 'src/providers/adb.service';

@Component({
  selector: 'app-file-explorer-folder-item',
  templateUrl: './file-explorer-folder-item.component.html',
  styleUrls: ['./file-explorer-folder-item.component.scss']
})
export class FileExplorerFolderItemComponent {

  @Input() file! : File
  childs : File[] | undefined = undefined
  isExpanded : boolean = false

  constructor(private adbService : AdbService, private changeDetector : ChangeDetectorRef) { }

  openFolder() {
    this.isExpanded = !this.isExpanded

    if (this.isExpanded) {
      this.adbService.getFiles(this.file.path).subscribe(files => {
        console.log(files);
        
        this.childs = files
        this.changeDetector.detectChanges()
      })
    }
    else {
      this.childs = undefined
      this.changeDetector.detectChanges()
    }
  }
}
