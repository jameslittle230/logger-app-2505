//
//  SetViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class SetViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var bigImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var currentImage: UIImage = UIImage() {
        didSet {
            bigImage.image = currentImage
        }
    }
    
    var set: Set?
    
    var logImages: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        if let set = self.set {
            self.logImages = set.getSortedImages()
            self.title = set.scene ?? "Untitled"
            currentImage = set.getFirstImage() ?? UIImage()
            setupFilmstripView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupFilmstripView() {
        let layout = UICollectionViewFlowLayout()
        let imageDimension = collectionView.frame.width / 8
        layout.itemSize = CGSize(width: imageDimension, height: imageDimension)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        collectionView.register(FilmstripCollectionViewCell.self, forCellWithReuseIdentifier: "filmstripCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return set?.logs?.count ?? 0
    }
    
    // https://youtu.be/WiETQhgV2uI
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filmstripCell", for: indexPath) as! FilmstripCollectionViewCell
        cell.awakeFromNib()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let filmstripCell = cell as! FilmstripCollectionViewCell
        filmstripCell.logImageView.image = logImages[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentImage = logImages[indexPath.row]
    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        <#code#>
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
