ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS (`bleed` INT(11) NOT NULL DEFAULT 0);

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('Bandage', 'Bandage', 10, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='Bandage', `label`='Bandage', `limit`=10, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('Rags', 'Rags', 10, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='Rags', `label`='Rags', `limit`=10, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('DocMorphine', 'Morphine', 5, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='DocMorphine', `label`='Morphine', `limit`=5, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('SmellingSalts', 'Smelling Salts', 5, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='SmellingSalts', `label`='Smelling Salts', `limit`=5, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('NeedleandThread', 'Needle and Thread', 5, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='NeedleandThread', `label`='Needle and Thread', `limit`=5, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';

INSERT INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES ('Doctor_Bag', 'Doctor Bag', 1, 1, 'item_standard', 1, '')
ON DUPLICATE KEY UPDATE `item`='Doctor_Bag', `label`='Doctor Bag', `limit`=1, `can_remove`=1, `type`='item_standard', `usable`=1, `desc`='';
