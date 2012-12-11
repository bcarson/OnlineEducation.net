if(window.location.href.indexOf("accounting") != -1) {
new QuickDegreeFinder().populate('.edudirect-degree_level_id',
								 '.edudirect-category_id',
								 '.edudirect-subject_id')
								 .setDefaults('Assoc', 'Business','Accounting');
	}